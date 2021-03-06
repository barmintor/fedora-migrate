require 'spec_helper'

describe FedoraMigrate::TargetConstructor do

  context "with one qualified model" do
    let(:list) { ["info:fedora/fedora-system:FedoraObject-3.0", "info:fedora/afmodel:String"] }
    subject { FedoraMigrate::TargetConstructor.new(list).build }
    it "should choose the one that is valid" do
      expect(subject.target).to eql String
    end
  end

  context "with multiple qualified models" do
    let(:list) { ["info:fedora/fedora-system:FedoraObject-3.0", "info:fedora/afmodel:Array", "info:fedora/afmodel:String"] }
    subject { FedoraMigrate::TargetConstructor.new(list).build }
    it "should choose the first one that is valid" do
      expect(subject.target).to eql Array
    end
  end

  context "with a single qualified model" do
    subject { FedoraMigrate::TargetConstructor.new("info:fedora/afmodel:Array").build }
    it "should be valid" do
      expect(subject.target).to eql Array
    end
  end

  context "with multiple unqualified models" do
    let(:list) { ["info:fedora/fedora-system:FedoraObject-3.0", "info:fedora/fedora-system:FooObject"] }
    subject { FedoraMigrate::TargetConstructor.new(list).build.target }
    it { is_expected.to be_nil }
  end

end
