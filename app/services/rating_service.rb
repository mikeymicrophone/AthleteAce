class RatingService
  # Archives the ace's active rating for this target and spectrum, then records the new one
  def self.replace(ace:, target:, spectrum_id: nil, value: nil, notes: nil)
    Rating.transaction do
      ace.ratings.active.where(target: target, spectrum_id: spectrum_id).each do |existing|
        existing.update!(archived: true)
      end

      ace.ratings.create!(target: target, spectrum_id: spectrum_id, value: value, notes: notes)
    end
  end
end
