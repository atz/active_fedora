require 'spec_helper'

describe "a versionable class" do
  before do
    class WithVersions < ActiveFedora::Base
      has_many_versions
      property :title, predicate: RDF::DC.title
    end
  end

  after do
    Object.send(:remove_const, :WithVersions)
  end

  subject { WithVersions.new }

  it "should be versionable" do
    expect(subject).to be_versionable
  end

  context "after saving" do
    before do
      subject.title = "Greetings Earthlings"
      subject.save
      subject.create_version
    end

    it "should set model_type to versionable" do
      expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
    end

    it "should have one version (plus the root version)" do
      expect(subject.versions.size).to eq 2
      expect(subject.versions.first).to be_kind_of RDF::URI
    end

    it "should have a root version" do
      expect(subject.root_version).to eq(subject.versions.first)
    end

    it "should have an initial version that equals its latest version" do
      expect(subject.latest_version).to eq(subject.initial_version)
    end

    context "two times" do
      before do
        subject.title = "Surrender and prepare to be boarded"
        subject.save
        subject.create_version
      end

      it "should have two versions (plus the root version)" do
        expect(subject.versions.size).to eq 3
        subject.versions.each do |version|
          expect(version).to be_kind_of RDF::URI
        end
      end

      context "then restoring" do
        let(:first_version) { subject.versions[1].to_s.split("/").last }
        before do
          subject.restore_version(first_version)
        end

        it "will return to the first version's values" do          
          expect(subject.versions.size).to eq 4
          expect(subject.title).to eql(["Greetings Earthlings"])        
        end

        context "and creating additional versions" do
          before do
            subject.title = "Now, surrender and prepare to be boarded"
            subject.save
            subject.create_version
          end

          it "should have five versions (plus the root version)" do
            expect(subject.versions.size).to eq 5
            expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
          end

        end
      end
    end
  end
end 

describe "a versionable rdf datastream" do
  before(:all) do
    class VersionableDatastream < ActiveFedora::NtriplesRDFDatastream
      has_many_versions
      property :title, predicate: RDF::DC.title
    end

    class MockAFBase < ActiveFedora::Base
      has_metadata "descMetadata", type: VersionableDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :VersionableDatastream)
  end

  subject { test_object.descMetadata }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    after do
      test_object.destroy
    end

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
      it "should not have a title" do
        expect(subject.title).to be_empty
      end
      it "should not have a size" do
        expect(subject.size).to be_nil
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
        @original_size = subject.size
      end

      it "should set model_type to versionable" do
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version (plus the root version)" do
        expect(subject.versions.size).to eq 2
        expect(subject.versions.first).to be_kind_of RDF::URI
      end

      it "should have a title" do
        expect(subject.title).to eql(["Greetings Earthlings"])
      end

      it "should have a size" do
        expect(subject.size).to_not be_nil
      end

      context "two times" do
        before do
          subject.title = "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two versions (plus the root version)" do
          expect(subject.versions.size).to eq 3
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::URI
          end
        end

        it "should have the new title" do
          expect(subject.title).to eql(["Surrender and prepare to be boarded"])
        end

        it "should have a new size" do
          expect(subject.size).to_not be_nil
          expect(subject.size).to_not eq(@original_size)
        end

        context "then restoring" do
          let(:first_version) { subject.versions[1].to_s.split("/").last }
          before do
            subject.restore_version(first_version)
          end

          it "should have three versions (plus the root version)" do          
            expect(subject.versions.size).to eq 4      
          end

          it "should load the restored datastream's content" do
            expect(subject.title).to eql(["Greetings Earthlings"])
          end

          it "should be the same size as the original datastream" do
            expect(subject.size).to eq @original_size
          end

          context "and creating additional versions" do
            before do
              subject.title = "Now, surrender and prepare to be boarded"
              subject.save
              subject.create_version
            end

            it "should have four versions (plus the root version)" do
              expect(subject.versions.size).to eq 5
            end

            it "should have a new title" do
              expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
            end

            it "should have a new size" do
              expect(subject.size).to_not eq @original_size
            end

          end
        end
      end
    end
  end
end

describe "a versionable OM datastream" do
  before(:all) do
    class VersionableDatastream < ActiveFedora::OmDatastream
      has_many_versions
      set_terminology do |t|
        t.root(path: "foo")
        t.title
      end
    end

    class MockAFBase < ActiveFedora::Base
      has_metadata "descMetadata", type: VersionableDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :VersionableDatastream)
  end

  subject { test_object.descMetadata }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    after do
      test_object.destroy
    end

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
      it "should not have a title" do
        expect(subject.title).to be_empty
      end
      it "should not have a size" do
        expect(subject.size).to be_nil
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
        @original_size = subject.size
      end

      it "should set model_type to versionable" do
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version (plus the root version)" do
        expect(subject.versions.size).to eq 2
        expect(subject.versions.first).to be_kind_of RDF::URI
      end

      it "should have a title" do
        expect(subject.title).to eql(["Greetings Earthlings"])
      end

      it "should have a size" do
        expect(subject.size).to_not be_nil
      end

      context "two times" do

        before do  
          subject.title = "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two versions (plus the root version)" do
          expect(subject.versions.size).to eq 3
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::URI
          end
        end

        it "should have the new title" do
          expect(subject.title).to eql(["Surrender and prepare to be boarded"])
        end

        it "should have a new size" do
          expect(subject.size).to_not be_nil
          expect(subject.size).to_not eq(@original_size)
        end

        context "then restoring" do
          let(:first_version) { subject.versions[1].to_s.split("/").last }
          before do
            subject.restore_version(first_version)
          end

          it "should have three versions (plus the root version)" do          
            expect(subject.versions.size).to eq 4      
          end

          it "should load the restored datastream's content" do
            expect(subject.title).to eql(["Greetings Earthlings"])
          end

          it "should be the same size as the original datastream" do
            expect(subject.size).to eq @original_size
          end

          context "and creating additional versions" do
            before do
              subject.title = "Now, surrender and prepare to be boarded"
              subject.save
              subject.create_version
            end

            it "should have four versions (plus the root version)" do
              expect(subject.versions.size).to eq 5
            end

            it "should have a new title" do
              expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
            end

            it "should have a new size" do
              expect(subject.size).to_not eq @original_size
            end

          end
        end
      end
    end
  end
end

describe "a versionable binary datastream" do
  before(:all) do
    class BinaryDatastream < ActiveFedora::Datastream
      has_many_versions 
    end

    class MockAFBase < ActiveFedora::Base
      has_file_datastream "content", type: BinaryDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :BinaryDatastream)
  end

  subject { test_object.content }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    after do
      test_object.destroy
    end

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
    end

    context "after creating the datastream" do
      let(:first_file) { File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" )) }
      let(:first_name) { "dino.jpg" }
      before do
        subject.content = first_file
        subject.original_name = first_name
        subject.save
        subject.create_version
      end

      it "should set model_type to versionable" do
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version (plus the root version)" do
        expect(subject.versions.size).to eq 2
        expect(subject.original_name).to eql(first_name)
        expect(subject.content.size).to eq first_file.size
        expect(subject.versions.first).to be_kind_of RDF::URI
      end

      context "two times" do
        let(:second_file) { File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" )) }
        let(:second_name) { "minivan.jpg" }
        before do
          subject.content = second_file
          subject.original_name = second_name
          subject.save
          subject.create_version
        end

        it "should have two versions (plus the root version)" do
          expect(subject.versions.size).to eq 3
          expect(subject.original_name).to eql(second_name)
          expect(subject.content.size).to eq second_file.size
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::URI
          end
        end

        context "then restoring" do
          let(:first_version) { subject.versions[1].to_s.split("/").last }
          before do
            subject.restore_version(first_version)
          end

          it "should have three versions (plus the root version)" do          
            expect(subject.versions.size).to eq 4      
          end

          it "should load the restored datastream's content" do
            expect(subject.content.size).to eq first_file.size
          end

          it "should load the restored datastream's original name" do
            expect(subject.original_name).to eql(first_name)
          end

          context "and creating additional versions" do
            before do
              subject.content = first_file
              subject.original_name = first_name
              subject.save
              subject.create_version
            end

            it "should have four versions (plus the root version)" do
              expect(subject.versions.size).to eq 5
              expect(subject.original_name).to eql(first_name)
              expect(subject.content.size).to eq first_file.size
              expect(subject.versions.first).to be_kind_of RDF::URI
            end

          end
        end
      end
    end
  end
end

describe "a versionable complex object" do

  before(:all) do
    class BinaryDatastream < ActiveFedora::Datastream
      has_many_versions 
    end
    class VersionableDatastream < ActiveFedora::NtriplesRDFDatastream
      has_many_versions
      property :title, predicate: RDF::DC.title
    end

    class ComplexObject < ActiveFedora::Base
      has_file_datastream "binaryData", type: BinaryDatastream, autocreate: true
      has_metadata "descMetadata", type: VersionableDatastream, autocreate: true
      property :title, predicate: RDF::DC.title
    end
  end

  after(:all) do
    Object.send(:remove_const, :ComplexObject)
    Object.send(:remove_const, :BinaryDatastream)
  end

  let(:complex_object) { ComplexObject.new }

  context "without data" do
    describe "the object's versions" do
      subject { complex_object.versions }
      it { is_expected.to be_empty }
    end

    describe "the datastreams' versions" do
      it "should be empty" do
        expect(complex_object.descMetadata.versions).to be_empty
        expect(complex_object.binaryData.versions).to be_empty
      end
    end
  end

  context "with data" do
    let(:first_file) { File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" )) }
    let(:first_name) { "dino.jpg" }
    before do
      complex_object.title = first_name
      complex_object.descMetadata.title = first_name
      complex_object.binaryData.content = first_file
      complex_object.binaryData.original_name = first_name
      complex_object.save
      complex_object.create_version
    end

    describe "the object's versions" do
      subject { complex_object.versions }
      it "should have one version (plus the root version)" do
        expect(subject.count).to eq 2
      end 
    end

    describe "the descriptive metadata datastream's versions" do
      subject { complex_object.descMetadata.versions }
      context "without calling .create_version" do
        it "should have no versions" do
          expect(subject.count).to eq 0
        end
      end
      context "after calling .create_version" do
        before do
          complex_object.descMetadata.create_version
        end
        it "should have one version (plus the root version)" do
          expect(subject.count).to eq 2
        end 
      end
    end

    describe "the binary datastream's versions" do
      subject { complex_object.binaryData.versions }
      context "without calling .create_version" do
        it "should have no versions" do
          expect(subject.count).to eq 0
        end
      end
      context "after calling .create_version" do
        before do
          complex_object.binaryData.create_version
        end
        it "should have one version (plus the root version)" do
          expect(subject.count).to eq 2
        end 
      end
    end

  end

end
