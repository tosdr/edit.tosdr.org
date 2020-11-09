json.array! @points do |point|
  json.extract! point, :id, :title, :source, :analysis, :case, :service
end
