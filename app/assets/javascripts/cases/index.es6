$(document).ready(function () {
  new Vue({
    el: '#dynamic-cases-table',
    data () {
      return {
        search: '',
        loading: true,
        cases: []
      }
    },
    methods: {
      fetchCases () {
        $.get(`/cases/list_all`)
          .then((response) => {
            this.cases = response
            this.loading = false
          })
      },
      // Most approved points first; ties broken by total points, then title.
      compareCases (a, b) {
        return (b.approved_points_count - a.approved_points_count) ||
          (b.points_count - a.points_count) ||
          (a.case.title || '').localeCompare(b.case.title || '')
      }
    },
    computed: {
      filteredCases () {
        const query = this.search.trim().toLowerCase()
        if (!query) return this.cases

        return this.cases.filter((c) => {
          const topicTitle = c.topic ? c.topic.title : ''
          return (c.case.title || '').toLowerCase().includes(query) ||
            topicTitle.toLowerCase().includes(query)
        })
      },
      // One entry per topic (alphabetical), each holding its sorted cases.
      // Topics with no cases matching the search are omitted.
      groupedCases () {
        const groups = {}
        this.filteredCases.forEach((c) => {
          const key = c.topic ? c.topic.id : 'none'
          if (!groups[key]) {
            groups[key] = { key: key, topic: c.topic, cases: [] }
          }
          groups[key].cases.push(c)
        })

        const topicTitle = (g) => g.topic ? g.topic.title : ''
        return Object.values(groups)
          .map((g) => Object.assign(g, { cases: g.cases.sort(this.compareCases) }))
          .sort((a, b) => {
            // Cases without a topic go last.
            if (!a.topic !== !b.topic) return a.topic ? -1 : 1
            return topicTitle(a).localeCompare(topicTitle(b))
          })
      }
    },
    mounted () {
      this.fetchCases()
    }
  })
})
