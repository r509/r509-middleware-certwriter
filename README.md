# r509-middleware-certwriter [![Build Status](https://secure.travis-ci.org/r509/r509-middleware-certwriter.png)](http://travis-ci.org/r509/r509-middleware-certwriter) [![Coverage Status](https://coveralls.io/repos/r509/r509-middleware-certwriter/badge.png?branch=master)](https://coveralls.io/r/r509/r509-middleware-certwriter?branch=master)

This project is related to [r509](http://github.com/r509/r509) and [r509-ca-http](http://github.com/r509/r509-ca-http), allowing you to save all issued certificates to the filesystem after they're issued. This is middleware so that you don't **need** to have your CA know anything about writing to the filesystem if you don't want to.

## Configuration

Add this to the ```config.ru``` file for your r509-ca-http instance.

```ruby
require 'r509/middleware/certwriter'

use R509::Middleware::Certwriter
run R509::CertificateAuthority::Http::Server
```

You'll also need to tell your CA where to save the issued certificates. Add this to the bottom of your r509-ca-http ```config.yaml```:

```yaml
certwriter: {
  path: "/absolute/path/to/wherever/you/want/the/certs"
}
```

Now every time a certificate is issued, it will be saved to the filesystem.
