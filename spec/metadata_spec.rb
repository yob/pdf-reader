# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::MetadataStrategy do
  include EncodingHelper

  it "should send the correct metadata callbacks when processing an PrinceXML PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = pdf_spec_file("prince1")
    PDF::Reader.file(filename, receiver)
    cb = receiver.first_occurance_of(:metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    expect(meta[:Producer]).to eql("YesLogic Prince 5.1")
  end

  it "should send the correct metadata callbacks when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = pdf_spec_file("openoffice-2.2")
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    expect(meta[:Creator]).to eql("Writer")
    expect(meta[:Producer]).to eql("OpenOffice.org 2.2")
    expect(meta[:CreationDate]).to eql("D:20070623021705+10'00'")
  end

  it "should send the correct xml_metadata callbacks when processing a distiller PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = pdf_spec_file("distiller_unicode")
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:xml_metadata)
    meta = cb[:args].first

    # check the metadata was extracted correctly
    expect(meta.include?("<pdf:Title>file://C:\\Data\\website\\i18nguy\\unicode-example.html</pdf:Title>")).to be_true
  end

  it "should send the correct page count callback when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = pdf_spec_file("openoffice-2.2")
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:page_count)
    expect(cb[:args].first).to eql(2)
  end

  it "should send the correct pdf_version callback when processing an openoffice PDF" do

    receiver = PDF::Reader::RegisterReceiver.new

    # process the instructions
    filename = pdf_spec_file("openoffice-2.2")
    PDF::Reader.file(filename, receiver, :pages => false)
    cb = receiver.first_occurance_of(:pdf_version)
    expect(cb[:args].first).to eql(1.4)
  end
end
