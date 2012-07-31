# coding: utf-8
require "#{File.dirname(__FILE__)}/spec_helper"
require "sinatra"
require "logger"
require "fileutils"

class TestServer < Sinatra::Base
    configure do
        set :config_pool, nil
    end

    error StandardError do
        env["sinatra.error"].message
    end

    get "/some/path/?" do
        "return value"
    end

    post "/1/certificate/issue/?" do
        if params["successful"]
            if params["cert"]
                params["cert"]
            else
                TestFixtures::CERT
            end
        elsif params["invalid_body"]
            "invalid cert body"
        else
            raise StandardError.new("Error")
        end
    end

    post "/1/certificate/revoke/?" do
        if params["successful"]
            "CRL"
        else
            raise StandardError.new("Error")
        end
    end

    post "/1/certificate/unrevoke/?" do
        if params["successful"]
            "CRL"
        else
            raise StandardError.new("Error")
        end
    end
end

describe R509::Middleware::Certwriter do
    before :all do
        @temp_write_directory = File.join("spec", "temp_write_directory")
        FileUtils.makedirs(@temp_write_directory)
    end
    before :each do
        @logger = double("logger")
        @config = double("config")
        @ca_cert = double("ca_cert")
        @config_pool = double("config_pool")
        Dependo::Registry[:log] = @logger
    end
    after :each do
        Dir.entries(@temp_write_directory).select{|x| not x.start_with?(".")}.each do |entry|
            File.delete(File.join(@temp_write_directory, entry))
        end
    end
    after :all do
        Dir.delete(@temp_write_directory)
    end
    
    def app
        test_server = TestServer
        test_server.send(:set, :config_pool, @config_pool)

        @app ||= R509::Middleware::Certwriter.new(test_server, @config)
    end

    context "some path" do
        it "returns some return value" do
            get "/some/path"
            last_response.body.should == "return value"
        end
    end

    context "issuing" do
        it "intercepts issuance" do
            filename = "langui.sh_testy_211653423715.pem"
            @config.should_receive(:[]).with("certwriter").and_return({"path"=>@temp_write_directory})
            @logger.should_receive(:info).with("Writing: #{File.join(@temp_write_directory, filename)}")

            post "/1/certificate/issue", :successful => true, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::CERT

            File.read(File.join(@temp_write_directory, filename)).should == TestFixtures::CERT
        end
        it "no certwriter" do
            filename = "langui.sh_testy_211653423715.pem"
            @config.should_receive(:[]).with("certwriter").and_return(nil)
            @logger.should_receive(:error).twice

            post "/1/certificate/issue", :successful => true, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::CERT

            File.exist?(File.join(@temp_write_directory, filename)).should == false
        end
        it "no certwriter path" do
            filename = "langui.sh_testy_211653423715.pem"
            @config.should_receive(:[]).with("certwriter").and_return({})
            @logger.should_receive(:error).twice

            post "/1/certificate/issue", :successful => true, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::CERT

            File.exist?(File.join(@temp_write_directory, filename)).should == false
        end
        it "fails issuance" do
            post "/1/certificate/issue/"
            last_response.status.should == 500
        end
        it "invalid cert body" do
            @logger.should_receive(:error).twice
            post "/1/certificate/issue", :invalid_body => true
            last_response.status.should == 200
            last_response.body.should == "invalid cert body"
        end
        it "wildcard" do
            filename = "*.xramp.com_testy_211653407360.pem"
            @config.should_receive(:[]).with("certwriter").and_return({"path"=>@temp_write_directory})
            @logger.should_receive(:info).with("Writing: #{File.join(@temp_write_directory, filename)}")

            post "/1/certificate/issue", :successful => true, :cert => TestFixtures::WILDCARD, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::WILDCARD

            File.read(File.join(@temp_write_directory, filename)).should == TestFixtures::WILDCARD.chomp
        end
        it "san" do
            filename = "langui.sh_testy_57953710177023404420300898930034339170.pem"
            @config.should_receive(:[]).with("certwriter").and_return({"path"=>@temp_write_directory})
            @logger.should_receive(:info).with("Writing: #{File.join(@temp_write_directory, filename)}")

            post "/1/certificate/issue", :successful => true, :cert => TestFixtures::SAN, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::SAN

            File.read(File.join(@temp_write_directory, filename)).should == TestFixtures::SAN.chomp
        end
        it "non-ascii characters" do
            filename = "ütf.com_testy_1347710705410875939179018156461170725106572413147.pem"
            @config.should_receive(:[]).with("certwriter").and_return({"path"=>@temp_write_directory})
            @logger.should_receive(:info).with("Writing: #{File.join(@temp_write_directory, filename)}")

            post "/1/certificate/issue", :successful => true, :cert => TestFixtures::UTF, :ca => "testy"
            last_response.status.should == 200
            last_response.body.should == TestFixtures::UTF

            File.read(File.join(@temp_write_directory, filename)).should == TestFixtures::UTF.chomp
        end
    end

    context "revoking" do
        it "intercepts revoke" do
            post "/1/certificate/revoke", :successful => true, :serial => 1234, :ca => "some_ca"
            last_response.status.should == 200
            last_response.body.should == "CRL"
        end
        it "fails to revoke" do
            post "/1/certificate/revoke"
            last_response.status.should == 500
        end
    end

    context "unrevoking" do
        it "intercepts unrevoke" do
            post "/1/certificate/unrevoke", :successful => true, :serial => 1234, :ca => "some_ca"
            last_response.status.should == 200
            last_response.body.should == "CRL"
        end
        it "fails to unrevoke" do
            post "/1/certificate/unrevoke"
            last_response.status.should == 500
        end
    end
end
