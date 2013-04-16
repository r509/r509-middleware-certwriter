require "r509"
require "dependo"

module R509
    module Middleware
        class Certwriter
            include Dependo::Mixin

            def initialize(app, config=nil)
                @app = app

                unless config
                    @config = YAML.load_file("config.yaml")
                else
                    @config = config
                end
            end

            def call(env)
                status, headers, response = @app.call(env)

                # we only care about issuance, and we just want to pull out the cert and write it to disk
                if not (env["PATH_INFO"] =~ /^\/1\/certificate\/issue\/?$/).nil? and status == 200
                    body = ""
                    response.each do |part|
                        body += part
                    end
                    begin
                        params = parse_params(env)
                        cert = R509::Cert.new(:cert => body)
                        file_path = @config["certwriter"]["path"]
                        filename = File.join(file_path,
                            "#{cert.subject.CN}_#{params["ca"]}_#{cert.hexserial}.pem").
                            gsub("*", "STAR").
                            encode(Encoding.find("ASCII"), {:invalid => :replace, :undef => :replace, :replace => "", :universal_newline => true})
                        log.info "Writing: #{filename}"
                        File.open(filename, "w"){|f| f.write(cert.to_s)}
                    rescue => e
                        log.error "Writing failed"
                        log.error e.inspect
                        if cert.respond_to?(:to_pem)
                          log.error cert.to_pem
                        end
                    end
                end

                [status, headers, response]
            end

            private

            def parse_params(env)
                raw_request = env["rack.input"].read
                env["rack.input"].rewind

                Rack::Utils.parse_query(raw_request)
            end
        end
    end
end
