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
        let self = this
        $.get(`/cases/list_all`)
          .then((response) => {
            self.cases = response
            self.loading = false
          })
      }
    },
    computed: {
      filteredCases () {
        return this.cases.filter((c) => {
          return c.case.title.toLowerCase().match(this.search.toLowerCase())
        })
      }
    },
    mounted () {
      this.cases = this.fetchCases()
    }
  })
})
