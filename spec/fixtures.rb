require 'spec_helper'
require 'pathname'

module TestFixtures
    FIXTURES_PATH = Pathname.new(__FILE__).dirname + "fixtures"

    def self.read_fixture(filename)
        File.read((FIXTURES_PATH + filename).to_s)
    end

    #Trustwave cert for langui.sh
    CERT = read_fixture('cert1.pem')
    WILDCARD = read_fixture('wildcard.pem')
    SAN = read_fixture('san.pem')
    UTF = read_fixture('utf.pem')
end
