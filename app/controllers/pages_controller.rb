class PagesController < ApplicationController
  def home
  end

  def app
    render layout: "react"
  end
end
