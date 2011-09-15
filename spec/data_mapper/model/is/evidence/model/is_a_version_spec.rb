require File.expand_path('../../../../../../spec_helper', __FILE__)

describe DataMapper::Model::Is::Evidence::Model, 'is_a_version' do
  before do
    subject
    DataMapper.finalize
  end

  let(:resource_with_versions) { DataMapper::Model.new(:ResourceWithVersions) }
  let(:version) { DataMapper::Model.new(:Version, resource_with_versions) }

  subject { version.is :a_version, :of => resource_with_versions }

  describe 'relationships' do
    it 'establishes a 1:m relationship (ResourceWithVersions -> Version)' do
      resource_with_versions.relationships[:versions].must_be_an_instance_of
        DataMapper::Associations::OneToMany::Relationship
    end
  end
end
