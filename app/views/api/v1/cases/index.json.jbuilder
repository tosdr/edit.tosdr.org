json.array! @cases do |c|
  json.extract! c, :id, :title, :description, :classification, :topic, :points
end
