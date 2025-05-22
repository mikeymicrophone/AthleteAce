class RatingService
  def self.update_or_replace(params, current_ace)
    spectrum_id = params[:spectrum_id]
    target_type = params[:target_type]
    target_id   = params[:target_id]

    # Archive existing active rating if present
    existing = current_ace.ratings.find_by(
      spectrum_id: spectrum_id,
      target_type: target_type,
      target_id: target_id,
      archived: false
    )
    existing.update!(archived: true) if existing

    # Create new rating with provided attributes
    current_ace.ratings.create!(
      spectrum_id: spectrum_id,
      value: params[:value],
      notes: params[:notes],
      target_type: target_type,
      target_id: target_id
    )
  end
end
