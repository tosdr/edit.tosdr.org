$(".points.edit").ready(function() {
  const pointCaseSelect = document.getElementById('point_case_id');
  if (!pointCaseSelect) {
    return;
  }

  pointCaseSelect.addEventListener('change', function() {

  let id = pointCaseSelect.selectedIndex;

  let title = pointCaseSelect.options[id].dataset.title;
  const pointTitleInput = document.querySelector("input[name='point[title]']");
  if (pointTitleInput) {
    pointTitleInput.setAttribute("value", title);
  }
  });
});
