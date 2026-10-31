import React, { useState } from 'react'

export default function MealPopover({ meal, children }) {
  const [open, setOpen] = useState(false)
  const hasContent = meal.description || meal.recipeUrl

  return (
    <span
      className="meal-popover-wrap"
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
    >
      {children}
      {open && hasContent && (
        <span className="meal-popover">
          {meal.description && <p className="meal-popover__desc">{meal.description}</p>}
          {meal.recipeUrl && (
            <a
              href={meal.recipeUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="meal-popover__link"
            >
              View recipe →
            </a>
          )}
        </span>
      )}
    </span>
  )
}
