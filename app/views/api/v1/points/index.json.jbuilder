json.array! @points do |point|
  json.extract! point, :id, :title, :source, :analysis, :rating, :service_id
end
