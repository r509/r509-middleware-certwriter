# r509-middleware-certwriter

This project is related to [r509](http://github.com/reaperhulk/r509) and [r509-ca-http](http://github.com/sirsean/r509-ca-http), allowing us to save all issued certificates to the filesystem after they're issued. This is middleware so that you don't **need** to have your CA know anything about writing to the filesystem if you don't want to.

# config.ru

    require 'r509/middleware/certwriter'

    use R509::Middleware::Certwriter
    run R509::CertificateAuthority::Http::Server

# config.yaml

You need to tell your CA where to save the issued certificates. Add this to the bottom of your ```config.yaml``` from **r509-ca-http**:

    certwriter: {
        path: "/absolute/path/to/wherever/you/want/the/certs"
    }

Now every time a certificate is issued, it will be saved to the filesystem.
