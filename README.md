This project is related to [r509](http://github.com/reaperhulk/r509) and [r509-ca-http](http://github.com/sirsean/r509-ca-http), allowing us to save all issued certificates to the filesystem after they're issued. This is middleware so that you don't **need** to have your CA know anything about writing to the filesystem if you don't want to.

If you want to use it, plug it into your config.ru, similar to this:

    require './lib/r509/CertificateAuthority/Http/Server'
    require 'r509/Middleware/Certwriter'

    use R509::Middleware::Certwriter
    run R509::CertificateAuthority::Http::Server
