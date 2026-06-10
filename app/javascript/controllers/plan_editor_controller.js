import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    weekStartDate: String,
    mealCount: Number,
    initialMeals: Array,  // Stimulus decodes HTML entities + JSON.parses automatically
    allMeals: Array
  }

  static targets = [
    "mealList",
    "status",
    "hiddenInputs",
    "mealCountInput",
    "mealCountHidden",
    "addMealSelect"
  ]

  connect() {
    this.state = {
      weekStartDate: this.weekStartDateValue,
      mealCount: this.mealCountValue,
      meals: this.initialMealsValue,  // already a parsed array
      manuallyExcludedIds: []  // any meal removed or swapped out — excluded from future suggestions
    }
    this.allMeals = this.allMealsValue  // already a parsed array
    this.render()
  }

  render() {
    this.renderMealList()
    this.updateStatus()
    this.updateAddMealSelect()
    this.syncHiddenInputs()
  }

  renderMealList() {
    this.mealListTarget.innerHTML = ""

    this.state.meals.forEach(meal => {
      const li = document.createElement("li")
      li.className = "plan-meal-item"
      li.dataset.mealId = meal.id

      const ratings = []
      if (meal.nutritionRating != null) ratings.push(`Nutrition: ${meal.nutritionRating}`)
      if (meal.kidsRating != null) ratings.push(`Kids: ${meal.kidsRating}`)
      if (meal.adultRating != null) ratings.push(`Adults: ${meal.adultRating}`)
      const ratingsHtml = ratings.map(r => `<span class="rating-badge">${r}</span>`).join("")

      const swapOptions = this.availableMeals()
        .map(m => `<option value="${m.id}">${m.title}</option>`)
        .join("")

      li.innerHTML = `
        <div class="plan-meal-item__info">
          <div class="plan-meal-item__title">${meal.title}</div>
          <div class="plan-meal-item__meta">
            ${meal.dinnerCount} ${meal.dinnerCount === 1 ? "night" : "nights"}
            ${ratingsHtml ? " &mdash; " + ratingsHtml : ""}
          </div>
          <div class="plan-meal-item__swap-panel" data-swap-panel="${meal.id}" style="display:none;">
            <select data-swap-select="${meal.id}" style="padding:0.4rem; border:1px solid #ccc; border-radius:6px;">
              <option value="">— Choose a replacement —</option>
              ${swapOptions}
            </select>
            <button type="button" class="btn btn--sm"
                    data-action="click->plan-editor#confirmSwap"
                    data-meal-id="${meal.id}">Swap</button>
            <button type="button" class="btn btn--sm"
                    data-action="click->plan-editor#pickForMe"
                    data-meal-id="${meal.id}">Pick for me</button>
            <button type="button" class="btn btn--sm"
                    data-action="click->plan-editor#cancelSwap"
                    data-meal-id="${meal.id}">Cancel</button>
          </div>
        </div>
        <div class="plan-meal-item__actions">
          <button type="button" class="btn btn--sm"
                  data-action="click->plan-editor#toggleSwap"
                  data-meal-id="${meal.id}">⇄ Swap</button>
          <button type="button" class="btn btn--sm btn--danger"
                  data-action="click->plan-editor#removeMeal"
                  data-meal-id="${meal.id}">×</button>
        </div>
      `
      this.mealListTarget.appendChild(li)
    })
  }

  removeMeal(event) {
    const id = parseInt(event.currentTarget.dataset.mealId)
    this.state.meals = this.state.meals.filter(m => m.id !== id)
    if (!this.state.manuallyExcludedIds.includes(id)) {
      this.state.manuallyExcludedIds.push(id)
    }
    this.render()
  }

  toggleSwap(event) {
    const id = parseInt(event.currentTarget.dataset.mealId)
    const targetPanel = this.mealListTarget.querySelector(`[data-swap-panel="${id}"]`)

    // Close all other open swap panels
    this.mealListTarget.querySelectorAll("[data-swap-panel]").forEach(panel => {
      if (panel !== targetPanel) {
        panel.style.display = "none"
      }
    })

    if (targetPanel) {
      targetPanel.style.display = targetPanel.style.display === "none" ? "flex" : "none"
    }
  }

  cancelSwap(event) {
    const id = parseInt(event.currentTarget.dataset.mealId)
    const panel = this.mealListTarget.querySelector(`[data-swap-panel="${id}"]`)
    if (panel) panel.style.display = "none"
  }

  confirmSwap(event) {
    const id = parseInt(event.currentTarget.dataset.mealId)
    const select = this.mealListTarget.querySelector(`[data-swap-select="${id}"]`)
    if (!select || !select.value) return

    const newMealId = parseInt(select.value)
    const newMeal = this.allMeals.find(m => m.id === newMealId)
    if (!newMeal) return

    if (!this.state.manuallyExcludedIds.includes(id)) {
      this.state.manuallyExcludedIds.push(id)
    }
    this.state.meals = this.state.meals.map(m => m.id === id ? newMeal : m)

    // Close all swap panels
    this.mealListTarget.querySelectorAll("[data-swap-panel]").forEach(panel => {
      panel.style.display = "none"
    })

    this.render()
  }

  async pickForMe(event) {
    const id = parseInt(event.currentTarget.dataset.mealId)

    // Record the displaced meal so it can't cycle back on repeated picks
    if (!this.state.manuallyExcludedIds.includes(id)) {
      this.state.manuallyExcludedIds.push(id)
    }

    const excludeIds = [
      ...this.state.meals.filter(m => m.id !== id).map(m => m.id),
      ...this.state.manuallyExcludedIds
    ]

    const params = new URLSearchParams()
    params.set("week_start_date", this.state.weekStartDate)
    params.set("swapped_meal_id", id)
    excludeIds.forEach(eid => params.append("exclude_meal_ids[]", eid))

    try {
      const response = await fetch(`/meal_plans/suggest_swap?${params.toString()}`, {
        headers: { Accept: "application/json" }
      })
      const data = await response.json()
      if (data.meals && data.meals.length > 0) {
        // Splice the replacement(s) in at the same position as the displaced meal.
        // A 2-night meal may be replaced by two 1-night meals (or another 2-night meal),
        // keeping the plan's total dinner-night count the same.
        const idx = this.state.meals.findIndex(m => m.id === id)
        this.state.meals.splice(idx, 1, ...data.meals)
        this.render()
      } else {
        alert("No suggestion available.")
      }
    } catch {
      alert("No suggestion available.")
    }
  }

  addMeal(event) {
    const select = this.addMealSelectTarget
    if (!select.value) return

    const id = parseInt(select.value)
    const meal = this.allMeals.find(m => m.id === id)
    if (!meal) return

    this.state.meals.push(meal)
    this.render()
  }

  onMealCountChange(event) {
    this.state.mealCount = parseInt(event.target.value)
    this.mealCountHiddenTarget.value = this.state.mealCount
    this.updateStatus()
  }

  async regenerate() {
    const params = new URLSearchParams()
    params.set("week_start_date", this.state.weekStartDate)
    params.set("meal_count", this.state.mealCount)
    this.state.manuallyExcludedIds.forEach(id => params.append("exclude_meal_ids[]", id))

    try {
      const response = await fetch(`/meal_plans/generate?${params.toString()}`, {
        headers: { Accept: "application/json" }
      })
      const data = await response.json()
      this.state.meals = data.meals
      this.render()
    } catch {
      alert("Failed to regenerate. Please try again.")
    }
  }

  save() {
    this.syncHiddenInputs()
    document.getElementById("plan-form").submit()
  }

  updateStatus() {
    const nightCount = this.state.meals.reduce((sum, m) => sum + (m.dinnerCount || 1), 0)
    const target = this.state.mealCount
    const el = this.statusTarget

    el.className = "plan-editor__status"

    if (nightCount === target) {
      el.classList.add("plan-editor__status--ok")
      el.textContent = `${nightCount} of ${target} dinner nights planned — looking good!`
    } else if (nightCount < target) {
      el.classList.add("plan-editor__status--short")
      el.textContent = `${nightCount} of ${target} dinner nights planned — ${target - nightCount} more needed.`
    } else {
      el.classList.add("plan-editor__status--over")
      el.textContent = `${nightCount} of ${target} dinner nights planned — ${nightCount - target} over target.`
    }
  }

  syncHiddenInputs() {
    const container = this.hiddenInputsTarget
    container.innerHTML = ""
    this.state.meals.forEach(meal => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "meal_ids[]"
      input.value = meal.id
      container.appendChild(input)
    })
  }

  updateAddMealSelect() {
    const select = this.addMealSelectTarget
    select.innerHTML = `<option value="">— Add a meal —</option>`
    this.availableMeals().forEach(meal => {
      const option = document.createElement("option")
      option.value = meal.id
      option.textContent = meal.title
      select.appendChild(option)
    })
  }

  availableMeals() {
    const currentIds = new Set(this.state.meals.map(m => m.id))
    return this.allMeals.filter(m => !currentIds.has(m.id))
  }
}
