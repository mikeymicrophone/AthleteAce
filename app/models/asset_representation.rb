class AssetRepresentation < ApplicationRecord
  include SeedObservation
  belongs_to :subject, polymorphic: true
  validates :subject_type, inclusion: { in: %w[Logo Uniform UniformPiece] }
  validates :file_format, :view, :canonical_path, :content_type, presence: true
  validates :view, uniqueness: { scope: [ :subject_type, :subject_id, :file_format ] }
  validates :sha256, format: { with: /\A[a-f0-9]{64}\z/ }
  validates :byte_size, numericality: { only_integer: true, greater_than: 0 }
  validate :relative_media_path

  def local_path(root: Rails.root.join("db/seeds/athlete_ace_data"))
    Pathname.new(root).join(canonical_path)
  end

  private

  def relative_media_path
    return if canonical_path&.start_with?("media/") && !canonical_path.split("/").include?("..") && !canonical_path.include?("\\")
    errors.add :canonical_path, "must be a relative path inside media/"
  end
end
