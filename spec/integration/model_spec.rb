require 'spec_helper'

include ActiveFedora::Model
include Mocha::API

describe ActiveFedora::Model do
  
  
  before(:each) do 
    module ModelIntegrationSpec
      
      class Base < ActiveFedora::Base
        include ActiveFedora::Model
        def self.pid_namespace
          "foo"
        end
      end
      class Basic < Base
      end
    end

    @test_instance = ModelIntegrationSpec::Basic.new
    @test_instance.save
    
  end
  
  after(:each) do
    @test_instance.delete
    Object.send(:remove_const, :ModelIntegrationSpec)
  end
  
  describe '#find' do
    it "should return an array of instances of the calling Class" do
      result = ModelIntegrationSpec::Basic.find(:all)
      result.should be_instance_of(Array)
      # this test is meaningless if the array length is zero
      result.length.should > 0
      result.each do |obj|
        obj.class.should == ModelIntegrationSpec::Basic
      end
    end
  end
  
  describe '#find_model' do
    
    it "should return an object of the given Model whose inner object is nil" do
      result = ModelIntegrationSpec::Basic.find_model(@test_instance.pid)
      result.class.should == ModelIntegrationSpec::Basic
      result.inner_object.new?.should be_false
    end
  end
  
end
