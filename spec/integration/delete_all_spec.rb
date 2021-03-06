require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
        class_attribute :callback_counter
        
        before_destroy :inc_counter

        def inc_counter
          self.class.callback_counter += 1
        end
      end
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end

  let!(:model1) { SpecModel::Basic.create! }
  let!(:model2) { SpecModel::Basic.create! }

  before do
    SpecModel::Basic.callback_counter = 0
  end


  describe ".destroy_all" do
    it "should remove both and run callbacks" do 
      SpecModel::Basic.destroy_all
      SpecModel::Basic.count.should == 0 
      SpecModel::Basic.callback_counter.should == 2
    end

    describe "when a model is missing" do
      let(:model3) { SpecModel::Basic.create! }
      let!(:pid) { model3.pid }
      before { model3.inner_object.delete }
      after do
        ActiveFedora::SolrService.instance.conn.tap do |conn|
          conn.delete_by_query "id:\"#{pid}\""
          conn.commit
        end
      end
      it "should be able to skip a missing model" do 
        expect(ActiveFedora::Base.logger).to receive(:error).with("Although #{pid} was found in Solr, it doesn't seem to exist in Fedora. The index is out of synch.")
        SpecModel::Basic.destroy_all
        SpecModel::Basic.count.should == 1 
      end
    end
  end

  describe ".delete_all" do
    it "should remove both and not run callbacks" do 
      SpecModel::Basic.delete_all
      SpecModel::Basic.count.should == 0
      SpecModel::Basic.callback_counter.should == 0
    end
  end
end
