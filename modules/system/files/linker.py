from collections import namedtuple
from sys import argv
import json
import os
import shutil
import tempfile

if not len(argv) == 3:
    print(f"Usage: {argv[0]} <old_system_links.json> <new_system_links.json>")
    exit(1)

with open(argv[1], "r") as file:
    old_files = json.load(file)

with open(argv[2], "r") as file:
    new_files = json.load(file)

if new_files['version'] != 1:
    print("Unknown schema version")
    exit(1)

DRY_RUN = 'DRY_RUN' in os.environ.keys()
CHECK_ONLY = 'CHECK_ONLY' in os.environ.keys()

Transaction = namedtuple("Transaction", ["source", "destination", "type"])
transactions: list[Transaction] = []
problems: list[str] = []

# Go through all files in the new generation
path: str
for path in new_files['files']:
    new_file = new_files['files'][path]
    if os.path.lexists(path):
        # There is a file at this path
        # It could be a regular file or a symlink (including broken symlinks)

        if os.path.islink(path):
            # The file is a symlink

            if path in old_files['files']:
                # The old generation had a file at this path
                if old_files['files'][path]['type'] == "link":
                    # The old generation's file was a link
                    link_target = os.readlink(path)
                    if os.path.join(os.path.dirname(path), link_target) == old_files['files'][path]['source']:
                        # The link has not changed since last system activation, so we can overwrite it
                        transactions.append(Transaction(new_file['source'], path, 'link'))
                    elif os.path.join(os.path.dirname(path), link_target) == new_file['source']:
                        # The link already points to the new target
                        continue
                    else:
                        # The link is to somewhere else
                        problems.append(path)
                else:
                    # The old generation's file was not a link.
                    # Because we know that the file on disk is a link,
                    # we know that we can't overwrite this file
                    problems.append(path)
            else:
                # The old generation did not have a file at this path,
                # and we never overwrite links that weren't created by us
                problems.append(path)
        else:
            # The file is a regular file
            problems.append(path)
    else:
        # There is no file at this path
        transactions.append(Transaction(new_file['source'], path, new_file['type']))

# Check problems
for problem in problems:
    print(f"Existing file at path {problem}")

if len(problems) > 0:
    print("Aborting")
    exit(1)

if CHECK_ONLY:
    # We don't perform any checks when planning removal of old files, so we can exit here
    exit(0)

# Remove all remaining files from the old generation that aren't in the new generation
path: str
for path in old_files['files']:
    old_file = old_files['files'][path]
    if path in new_files['files']:
        # Already handled when we iterated through new_files above
        continue
    if os.path.lexists(path):
        # There is a file at this path
        # It could be a regular file or a symlink (including broken symlinks)

        if os.path.islink(path):
            # The file is a symlink

            if old_file['type'] != "link":
                # This files wasn't a link at last activation, which means that the user changed it
                # Therefore we don't touch it
                continue

            # Check that its destination remains the same
            link_target = os.readlink(path)
            if os.path.join(os.path.dirname(path), link_target) == old_file['source']:
                # The link has not changed since last system activation, so we can overwrite it
                transactions.append(Transaction(path, path, "remove"))
            else:
                # The link is to somewhere else, so leave it alone
                continue
        else:
            # The file is a regular file
            continue
    else:
        # There's no file at this path anymore, so we have nothing to do anyway
        continue

# Perform all transactions
for t in transactions:
    # NOTE: the naming scheme for transaction properties is confusing
    # We are **NOT** using the same scheme as symlinks when we talk about
    # source/destination. The way we are using these names, `source` is a path
    # in the Nix store, and `destination` is the path in the system where the source
    # should be linked or copied to.
    # In the special case of removing files, `destination` can be ignored
    if DRY_RUN:
        match t.type:
            case "link":
                print(f"ln -s {t.source} {t.destination}")
            case "remove":
                print(f"rm {t.source}")
            case _:
                print(f"Unknown transaction type {t.type}")
    else:
        match t.type:
            case "link":
                # TODO: ensure enclosing directory exists

                # https://stackoverflow.com/a/55742015/8387516
                dir = os.path.dirname(t.destination)
                while True:
                    temp_name = tempfile.mktemp(dir=dir)
                    try:
                        os.symlink(t.source, temp_name)
                        break
                    except FileExistsError:
                        pass
                os.replace(temp_name, t.destination)
            case "remove":
                os.remove(t.source)
            case _:
                print(f"Unknown transaction type {t.type}")
