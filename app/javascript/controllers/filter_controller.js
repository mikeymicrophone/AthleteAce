import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  applyFilter(event) {
    const selectElement = event.target
    const filterKey = selectElement.dataset.filterKey
    const resource = selectElement.dataset.filterResource
    const selectedValue = selectElement.value

    if (!selectedValue || !filterKey || !resource) {
      console.warn("Filter missing required data:", { selectedValue, filterKey, resource })
      return
    }

    let path = `/${filterKey}s/${selectedValue}/${resource}`

    const currentParams = new URLSearchParams(window.location.search)
    if (currentParams.toString()) {
      path += `?${currentParams.toString()}`
    }

    window.location.href = path
  }
}
