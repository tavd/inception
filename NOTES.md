# Development Notes

This file contains technical notes and workarounds discovered while developing and testing the Inception project, particularly those related to the school VM and VirtualBox environment.

## School Host → VM Testing

The Docker project runs inside the Debian VM.

In the school environment, VirtualBox forwards the school host's port `8443` to port `443` inside the VM:

```text
School host
    │
    │ 127.0.0.1:8443
    ▼
VirtualBox
    │
    │ VM :443
    ▼
NGINX
    │
    ▼
WordPress
```

The project itself uses HTTPS on port `443`. The `8443` port is only part of the school host's VirtualBox port-forwarding configuration.

### Testing from the school host

The host-to-VM HTTPS connection can be tested with:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful response should be similar to:

```text
HTTP/1.1 200 OK
Server: nginx
```

The `Host` header is used because the request is sent to `127.0.0.1`, while NGINX is configured for:

```nginx
server_name tavdiiev.42.fr www.tavdiiev.42.fr;
```

This tests the path:

```text
School host
    │
    │ 127.0.0.1:8443
    ▼
VirtualBox
    │
    │ VM :443
    ▼
NGINX
    │
    ▼
WordPress
```

## Browser Testing from the School Host

The project can be accessed from a browser on the school host through the VirtualBox forwarding port:

```text
https://tavdiiev.42.fr:8443/
```

If the school host cannot resolve `tavdiiev.42.fr`, a separate Chrome instance can be started with:

```bash
google-chrome \
    --user-data-dir=/tmp/chrome-test \
    --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"
```

The `--user-data-dir=/tmp/chrome-test` option uses a separate temporary Chrome profile.

The `--host-resolver-rules` option makes `tavdiiev.42.fr` resolve to `127.0.0.1` for this Chrome instance.

## WordPress URL and Port 8443

The project's canonical WordPress URL is:

```text
https://tavdiiev.42.fr
```

The WordPress `home` and `siteurl` options normally use this URL without `:8443`.

However, the school host accesses the VM through:

```text
https://tavdiiev.42.fr:8443
```

This can cause WordPress to redirect the browser to its canonical URL without `:8443`.

### Temporary browser-testing workaround

For a temporary browser test through the school host, both `home` and `siteurl` can be changed to include the forwarding port:

```bash
docker exec wordpress wp option update home 'https://tavdiiev.42.fr:8443' --allow-root
docker exec wordpress wp option update siteurl 'https://tavdiiev.42.fr:8443' --allow-root
```

This allows WordPress to generate links and redirects using the host-side forwarding port during the browser test.

After testing, restore both options to the canonical URL:

```bash
docker exec wordpress wp option update home 'https://tavdiiev.42.fr' --allow-root
docker exec wordpress wp option update siteurl 'https://tavdiiev.42.fr' --allow-root
```

## Alternative: Testing through 127.0.0.1:8443

Another browser-testing approach is to temporarily use the host's forwarded `127.0.0.1:8443` address directly.

Set both WordPress options to:

```bash
docker exec wordpress wp option update home 'https://127.0.0.1:8443' --allow-root
docker exec wordpress wp option update siteurl 'https://127.0.0.1:8443' --allow-root
```

The site can then be accessed from the school host at:

```text
https://127.0.0.1:8443/
```

This avoids the need to make the browser resolve `tavdiiev.42.fr` to `127.0.0.1`.

After testing, restore both options to:

```bash
docker exec wordpress wp option update home 'https://tavdiiev.42.fr' --allow-root
docker exec wordpress wp option update siteurl 'https://tavdiiev.42.fr' --allow-root
```

The `127.0.0.1:8443` address is only a temporary school-host testing address.

Do not permanently add `:8443` to `WP_URL`, `home`, or `siteurl`.

The `:8443` port belongs only to the school's VirtualBox host-to-VM forwarding configuration and is not part of the project's canonical WordPress URL.
