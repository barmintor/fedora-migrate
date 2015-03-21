require 'spec_helper'

describe "Migrating an object" do

  let(:source)    { FedoraMigrate.source.connection.find("sufia:rb68xc089") }
  let(:fits_xml)  { load_fixture("sufia-rb68xc089-characterization.xml").read }

  context "when the target model is provided" do

    let(:mover) { FedoraMigrate::ObjectMover.new source, ExampleModel::MigrationObject.new }

    subject do
      mover.migrate
      mover.target
    end

    it "should migrate the entire object" do
      expect(subject.content.versions.all.count).to eql 3
      expect(subject.thumbnail.mime_type).to eql "image/jpeg"
      expect(subject.thumbnail.versions.all.count).to eql 0
      expect(subject.characterization.content).to be_equivalent_to(fits_xml)
      expect(subject.characterization.versions.all.count).to eql 0
      expect(subject).to be_kind_of ExampleModel::MigrationObject
    end

    it "should migrate the object's permissions" do
      expect(subject.edit_users).to include("jilluser@example.com")
    end

    describe "objects with Om datastreams" do
      let(:mover) { FedoraMigrate::ObjectMover.new(source, ExampleModel::OmDatastreamExample.new) }
      subject do
        mover.migrate
        mover.target
      end
      it "should migrate the object without warnings" do
        expect(FedoraMigrate::Logger).to_not receive(:warn)
        expect(subject.characterization.ng_xml).to be_equivalent_to(fits_xml)
      end
    end
    context "targets with custom file contents migrations" do
      before do
        class ConstantContentMover < FedoraMigrate::DatastreamMover
          def migrate
            target.content = "a test for constant content"
            save
            report # can't call super if inheriting from DatastreamMover
          end
        end
      end
      after do
        Object.send(:remove_const, :ConstantContentMover) if defined?(ConstantContentMover)
      end
      let(:mover) do
        m = FedoraMigrate::ObjectMover.new(source, ExampleModel::TransformedObject.new)
        m.content_conversions['transform'] = ConstantContentMover
        m
      end
      subject do
        mover.migrate
        mover.target
      end
      it "should perform the custom migration on non-existent source datastreams" do
        expect(subject.transform.content).to eql("a test for constant content")
      end
    end
  end

  context "when we have to determine the model" do

    let(:mover) { FedoraMigrate::ObjectMover.new source }

    context "and it is defined" do

      before do
        Object.send(:remove_const, :GenericFile) if defined?(GenericFile)
        class GenericFile < ActiveFedora::Base
          contains "content", class_name: "ExampleModel::VersionedDatastream"
          contains "thumbnail", class_name: "ActiveFedora::Datastream"
          contains "characterization", class_name: "ActiveFedora::Datastream"
        end
      end

      subject do
        mover.migrate
        mover.target
      end

      it "should migrate the entire object" do
        expect(subject.content.versions.all.count).to eql 3
        expect(subject.thumbnail.mime_type).to eql "image/jpeg"
        expect(subject.thumbnail.versions.all.count).to eql 0
        expect(subject.characterization.content).to be_equivalent_to(fits_xml)
        expect(subject.characterization.versions.all.count).to eql 0
        expect(subject).to be_kind_of GenericFile
      end
    end

    context "and it is not defined" do
      before do
        Object.send(:remove_const, :GenericFile) if defined?(GenericFile)
      end
      it "should fail" do
        expect{mover.migrate}.to raise_error(FedoraMigrate::Errors::MigrationError)
      end
    end

  end

  context "when the object has an ntriples datastream" do

    context "and we want to convert it to a provided model" do
      let(:mover) { FedoraMigrate::ObjectMover.new(source, ExampleModel::RDFObject.new, {convert: "descMetadata"}) }

      subject do
        mover.migrate
        mover.target
      end

      it "should migrate the entire object" do
        expect(subject.content.versions.all.count).to eql 3
        expect(subject.thumbnail.mime_type).to eql "image/jpeg"
        expect(subject.thumbnail.versions.all.count).to eql 0
        expect(subject.characterization.content).to be_equivalent_to(fits_xml)
        expect(subject.characterization.versions.all.count).to eql 0
        expect(subject).to be_kind_of ExampleModel::RDFObject
        expect(subject.title).to eql(["world.png"])
      end

      it "should migrate the createdDate and lastModifiedDate" do
        # The value of lastModifiedDate will depend on when you loaded your test fixtures
        expect(subject.date_modified).to eq source.lastModifiedDate
        expect(subject.date_uploaded).to eq '2014-10-15T03:50:37.063Z'
      end
    end

    context "with ISO-8859-1 characters" do
      let(:problem_source) { FedoraMigrate.source.connection.find("scholarsphere:5712mc568") }
      let(:mover) { FedoraMigrate::ObjectMover.new(problem_source, ExampleModel::RDFObject.new, {convert: "descMetadata"}) }
      subject do
        mover.migrate
        mover.target
      end

      it "should migrate the content" do
        expect(subject.description.first).to match(/^The relationship between school administrators and music teachers/)
      end

    end

    context "and we want to convert multiple datastreas" do

      # Need a fixture with two different datastreams for this test to be more effective
      let(:mover) { FedoraMigrate::ObjectMover.new(source, ExampleModel::RDFObject.new, {convert: ["descMetadata", "descMetadata"]}) }

      subject do
        mover.migrate
        mover.target
      end

      it "should migrate all the datastreams" do
        expect(subject.title).to eql(["world.png"])
      end
    end

    context "with RDF errors" do
      let(:problem_source) { FedoraMigrate.source.connection.find("scholarsphere:sf2686078") }
      let(:mover) { FedoraMigrate::ObjectMover.new(problem_source, ExampleModel::RDFObject.new, {convert: "descMetadata"}) }
      subject do
        mover.migrate
        mover.target
      end

      it "should migrate the content" do
        expect(subject.title).to eql([" The \"Value Added\" in Editorial Acquisitions.pdf"])
      end
    end

  end

end
