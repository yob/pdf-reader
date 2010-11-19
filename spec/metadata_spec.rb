# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::MetadataStrategy do
  include EncodingHelper

  it "should send the correct metadata callbacks when processing an PrinceXML PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = File.dirname(__FILE__) + "/data/prince1.pdf"
    PDF::Reader.file(filename, receiver)
    cb = receiver.first_occurance_of(:metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    meta[:Producer].should eql("YesLogic Prince 5.1")
  end

  it "should send the correct metadata callbacks when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = File.dirname(__FILE__) + "/data/openoffice-2.2.pdf"
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    meta[:Creator].should eql("Writer")
    meta[:Producer].should eql("OpenOffice.org 2.2")
    meta[:CreationDate].should eql("D:20070623021705+10'00'")
  end

  it "should send the correct xml_metadata callbacks when processing a distiller PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = File.dirname(__FILE__) + "/data/distiller_unicode.pdf"
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:xml_metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    meta.include?("<pdf:Title>file://C:\\Data\\website\\i18nguy\\unicode-example.html</pdf:Title>").should be_true
  end

  it "should send the correct page count callback when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = File.dirname(__FILE__) + "/data/openoffice-2.2.pdf"
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:page_count)
    cb[:args].first.should eql(2)
  end

  it "should send the correct pdf_version callback when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = File.dirname(__FILE__) + "/data/openoffice-2.2.pdf"
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:pdf_version)
    cb[:args].first.should eql(1.4)
  end
end
