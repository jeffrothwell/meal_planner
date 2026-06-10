class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Serves the React shell for HTML requests on migrated pages.
  # React Router renders the correct component; data comes via the JSON branch.
  def render_react_app
    render "pages/app", layout: "react"
  end
end
