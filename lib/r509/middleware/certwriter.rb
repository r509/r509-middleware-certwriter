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
                        cert = R509::Cert.new(:cert => body)
                        file_path = @config["certwriter"]["path"]
                        filename = File.join(file_path, "#{cert.subject_component("CN")}_#{cert.serial}.pem")
                        log.info "Writing: #{filename.force_encoding("utf-8")}"
                        File.open(filename, "w"){|f| f.write(cert.to_s)}
                    rescue => e
                        log.error "Writing failed"
                        log.error e.inspect
                    end
                end

                [status, headers, response]
            end
        end
    end
end
