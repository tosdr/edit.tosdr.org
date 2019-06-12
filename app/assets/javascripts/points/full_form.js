$(".points.edit").ready(function() {
  document.getElementById('point_case_id').addEventListener('change', function() {

  let id = document.getElementById('point_case_id').selectedIndex;

  let title = document.getElementById('point_case_id').options[id].dataset.title;
  document.querySelectorAll("input[name='point[title]']")[0].setAttribute("value", title);
  });
});
