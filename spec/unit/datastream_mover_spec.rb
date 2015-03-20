require 'spec_helper'

describe FedoraMigrate::DatastreamMover do

  describe "#post_initialize" do
    specify "a target is required" do
      expect{subject.new}.to raise_error(StandardError)
    end
  end

  describe "#versionable?" do

    let(:versionable_file)     { instance_double("Versionable File", :versionable? => true) }
    let(:non_versionable_file) { instance_double("Nonversionable File", :versionable? => false) }
    let(:source) { instance_double("Source", :datastreams => {})}
    let(:file) { instance_double("File")}
    context "by default" do
      let(:target) { instance_double("Target", :attached_files => Hash.new(file))}
      subject { FedoraMigrate::DatastreamMover.new(source,target, ds_key: 'foo') }
      it { is_expected.to_not be_versionable }
    end
    context "when the datastream is not versionable" do
      let(:target) { instance_double("Target", :attached_files => Hash.new(non_versionable_file))}
      subject { FedoraMigrate::DatastreamMover.new(source, target, ds_key: 'foo') }
      it { is_expected.to_not be_versionable }
    end
    context "when the datastream is versionable" do
      let(:target) { instance_double("Target", :attached_files => Hash.new(versionable_file))}
      subject { FedoraMigrate::DatastreamMover.new(source, target, ds_key: 'foo') }
      it { is_expected.to be_versionable }
      context "but you want to override that" do
        subject do
          mover = FedoraMigrate::DatastreamMover.new(source, target, ds_key: 'foo')
          mover.versionable = false
          return mover
        end
        it { is_expected.to_not be_versionable }
      end
    end
  
  end

end
