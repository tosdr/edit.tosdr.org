json.array! @topics do |t|
  json.extract! t, :id, :title, :subtitle
end
