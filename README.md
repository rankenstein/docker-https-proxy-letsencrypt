Start a HTTPS server that acts as a proxy to other HTTP servers. The idea is that you run your web applications in separate containers and link this container to them.

Example:

```bash
docker create \
	--name "https-proxy" \
	-p 80:80 \
	-p 443:443 \
	--link test:test \
	--link webapp1:webapp1 \
	--link webapp2:webapp2 \
	-e "HOST_example_com=http://test/" \
	-e "HOST_example_org=/webapp1/|http://webapp1/|/webapp2/|http://webapp2/" \
	-v ssl:/ssl \
	rankenstein/https-proxy

docker start -a https-proxy
```

Environment
===========

* `SSL_COMPATIBILITY`: [SSL compatibility level](https://wiki.mozilla.org/Security/Server_Side_TLS), can be `modern` (default), `intermediate` or `old`
* `SSL_CHAIN`: Default SSL certificate chain. Will be taken from file `/ssl/<SSL_CHAIN>.pem`.
* `SSL_FALLBACK_KEY`: Fallback SSL key in case the browser does not support SNI. Is expected in file `/ssl/<SSL_KEY>.crt` and `/ssl/<SSL_KEY>.key`.
* `SSL_FALLBACK_CHAIN`: SSL certificate chain for the fallback key. Expected in file `/ssl/<SSL_FALLBACK_CHAIN>.pem`.
* `HOST_<hostname_with_underscores>`: `hostname_with_underscores` is the host name under which to listen (replace `.` by `_`). The SSL certificate will be taken from the files `/ssl/<hostname>.crt` and `/ssl/<hostname>.key` (for example `/ssl/example.com.{crt,key}`). The value can be the simple form `<url>`, where `url` is the URL to proxy to (for example `http://example.com/`). To map certain paths to certain URLs, use the extend form `<path1>|<url1>|<path2>|<url2>|<…>`, where `path` is the path that should be mapped to the URL `url` (specifying `HOST_www_example_com=/webapp1/|http://webapp1/` will proxy the URL `https://www.example.com/webapp1/` to `http://webapp1/`). The order is important, paths with less slashes should come earlier in the list.
* `ALLOW_NONSSL_<hostname_with_underscore>`: Set to `yes` to disable forwarding from http to https for this host.
* `SSL_CHAIN_<hostname_with_underscore>`: Custom SSL certificate chain for this host. Will be taken from file `/ssl/<chain>.pem`.
* `REDIRECT_<hostname_with_underscore>`: Redirect instead of proxy. The value can be a status code or one of `temp`, `permanent`, or `seeother`.
* `ALIAS_<hostname_with_underscore>`: A space-separated list of alias hostnames. Possible to use wildcards.
* `PRESERVE_HOST` and `PRESERVE_HOST_<hostname_with_underscore>`: Set to `yes` to send original host name via proxy.
