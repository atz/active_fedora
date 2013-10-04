require 'spec_helper'

describe "When two or more relationships share the same property" do 
  before do
    class Book < ActiveFedora::Base 
      has_many :collections, :class_name=>'Collection'
      has_many :people
    end

    class Person < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    class Collection < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    @book = Book.create!
    @person1 = Person.create!(:book=>@book)
    @person2 = Person.create!(:book=>@book)
  end
  after do
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :Book)
  end

  it "Should only return relationships of the correct class" do
    @book.reload
    @book.people.should == [@person1, @person2]
    @book.collections.should == []
  end
end

describe "When relationship is restricted to AF::Base" do
  before do
    class Email < ActiveFedora::Base 
      has_many :attachments, :property=>:is_part_of, :class_name=>'ActiveFedora::Base'
    end

    class Image < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end

    class PDF < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end
  end

  after do
      Object.send(:remove_const, :Image)
      Object.send(:remove_const, :PDF)
      Object.send(:remove_const, :Email)
  end


  describe "creating new objects with object relationships" do
    before do
      @book = Email.create!
      @image = Image.create!(:email=>@book)
      @pdf = PDF.create!(:email=>@book)
    end
    it "Should not restrict relationships " do
      @book.reload
      @book.attachments.should == [@image, @pdf]
    end
  end

  describe "creating new objects with id setter" do
    let!(:image) { Image.create }
    let!(:email) { Email.create }
    let!(:pdf) { PDF.create }

    after do
      email.destroy
      pdf.destroy
      image.destroy
    end

    it "Should not restrict relationships " do
      Deprecation.should_not_receive(:warn) # a deprecation in 6.6.0 that's going away in 7.0.0
      email.attachment_ids = [image.id, pdf.id]
      email.reload
      email.attachments.should == [image, pdf]
    end
  end
end
