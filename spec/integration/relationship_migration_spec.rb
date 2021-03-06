require 'spec_helper'

describe "Migrating objects with relationships" do

  before :all do
    class GenericFile < ActiveFedora::Base
      belongs_to :batch, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      property :title, predicate: ::RDF::DC.title do |index|
        index.as :stored_searchable, :facetable
      end
      property :creator, predicate: ::RDF::DC.creator do |index|
        index.as :stored_searchable, :facetable
      end
    end

    class Batch < ActiveFedora::Base
      has_many :generic_files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end
  end

  after :all do
    Object.send(:remove_const, :GenericFile) if defined?(GenericFile)
  end

  let(:parent_source) { FedoraMigrate.source.connection.find("sufia:rb68xc09k") }
  let(:child_source)  { FedoraMigrate.source.connection.find("sufia:rb68xc11m") }

  context "when all objects exist in Fedora4" do

    before do
      FedoraMigrate::ObjectMover.new(parent_source).migrate
      FedoraMigrate::ObjectMover.new(child_source).migrate
    end

    subject { Batch.find("rb68xc09k") }

    describe "migrating the parent object's relationships" do
      before do
        FedoraMigrate::RelsExtDatastreamMover.new(child_source).migrate
      end
      specify "should connect the child to the parent" do
        expect(subject.generic_files.count).to eql 1
      end
      specify "is repeatable" do
        FedoraMigrate::RelsExtDatastreamMover.new(child_source).migrate
        expect(subject.generic_files.count).to eql 1
      end
    end

  end

end
