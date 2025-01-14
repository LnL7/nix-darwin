const anchor = document.location.hash.substring(1);
const redirects = {};
if (redirects[anchor]) document.location.href = redirects[anchor];
