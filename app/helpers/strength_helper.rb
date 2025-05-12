module StrengthHelper



  def pause_button stimulus_controller = "team-match"
    tag.div class: "pause-button" do
      tag.button "<i class='fa-solid fa-pause mr-2'></i> Pause".html_safe,
        class: "bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200",
        data: {
          (stimulus_controller.underscore + "_target") => "pauseButton",
          action: "click->#{stimulus_controller}#togglePause"
        }
    end
  end
end
