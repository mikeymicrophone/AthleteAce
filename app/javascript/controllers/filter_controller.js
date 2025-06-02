import { Controller } from "@hotwired/stimulus"

// Handles filtering resources using the filterable concern
export default class extends Controller {
  connect() {
    console.log("Filter controller connected")
  }
  
  applyFilter(event) {
    const selectElement = event.target
    const filterKey = selectElement.dataset.filterKey
    const resource = selectElement.dataset.filterResource
    const selectedValue = selectElement.value
    
    if (!selectedValue) return
    
    // Build the filter path
    let path = `/${filterKey}s/${selectedValue}/${resource}`
    
    // Add any existing query parameters
    const currentParams = new URLSearchParams(window.location.search)
    if (currentParams.toString()) {
      path += `?${currentParams.toString()}`
    }
    
    // Navigate to the filtered URL
    window.location.href = path
  }
}
