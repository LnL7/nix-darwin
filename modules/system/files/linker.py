from dataclasses import dataclass
from sys import argv, exit
import json
import os
from pathlib import Path

if len(argv) != 3:
    print(f"Usage: {argv[0]} <old_system_links.json> <new_system_links.json>")
    exit(1)

class FileInfo:
    source: Path
    type: str

    def __init__(self, d):
        self.source = Path(d['source'])
        self.type = d['type']

with open(argv[1], "r") as file:
    data = json.load(file)
    if data['version'] != 1:
        print(f"Unknown schema version in {argv[1]}")
        exit(1)
    old_files: dict[Path, FileInfo] = {
        Path(k): FileInfo(v)
        for
        (k,v)
        in
        data['files'].items()
    }

with open(argv[2], "r") as file:
    data = json.load(file)
    if data['version'] != 1:
        print(f"Unknown schema version in {argv[2]}")
        exit(1)
    new_files: dict[Path, FileInfo] = {
        Path(k): FileInfo(v)
        for
        (k,v)
        in
        data['files'].items()
    }

DRY_RUN = 'DRY_RUN' in os.environ.keys()
CHECK_ONLY = 'CHECK_ONLY' in os.environ.keys()

@dataclass
class Transaction:
    source: Path
    destination: Path
    type: str
transactions: list[Transaction] = []
problems: list[Path] = []

path: Path
# Go through all files in the new generation
for path in new_files:
    new_file: FileInfo = new_files[path]
    if path.exists(follow_symlinks=False):
        # There is a file at this path
        # It could be a regular file or a symlink (including broken symlinks)

        if path.is_symlink():
            # The file is a symlink

            if path in old_files:
                # The old generation had a file at this path
                if old_files[path].type == "link":
                    # The old generation's file was a link
                    link_target = path.readlink()
                    # This handles both relative and absolute symlinks
                    #   If the link is relative, we need to prepend the parent
                    #   If the link is absolute, the prepended parent is ignored
                    if path.parent / link_target == old_files[path].source:
                        # The link has not changed since last system activation, so we can overwrite it
                        transactions.append(Transaction(new_file.source, path, 'link'))
                    elif path.parent / link_target == new_file.source:
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
        transactions.append(Transaction(new_file.source, path, new_file.type))

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
path: Path
for path in old_files:
    old_file: FileInfo = old_files[path]
    if path in new_files:
        # Already handled when we iterated through new_files above
        continue
    if path.exists(follow_symlinks=False):
        # There is a file at this path
        # It could be a regular file or a symlink (including broken symlinks)

        if path.is_symlink():
            # The file is a symlink

            if old_file.type != "link":
                # This files wasn't a link at last activation, which means that the user changed it
                # Therefore we don't touch it
                continue

            # Check that its destination remains the same
            link_target = path.readlink()
            if path.parent / link_target == old_file.source:
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

enclosingDirectories: list[Path] = []
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
                # Ensure parent directory exists
                path.parent.mkdir(parents=True,exist_ok=True)
                # Remove the file if it exists (we should only get to this case if it's an old symlink we're replacing)
                # This does not properly handle race conditions, but I think we'd fail in the checking stage
                #   if your config has a race condition
                t.destination.unlink(missing_ok=True)
                # Link the file into place
                t.destination.symlink_to(t.source)
            case "remove":
                enclosingDirectories.append(t.source.parent)
                t.source.unlink()
            case _:
                print(f"Unknown transaction type {t.type}")

for directory in enclosingDirectories:
    if not directory.is_dir():
        continue
    if any(directory.iterdir()):
        continue
    print(f"The directory {directory} has been emptied; you may want to remove it")
