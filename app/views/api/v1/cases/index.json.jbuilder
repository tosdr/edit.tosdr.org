json.array! @cases do |c|
  json.extract! c, :id, :title, :score, :description, :classification, :topic, :points
end
