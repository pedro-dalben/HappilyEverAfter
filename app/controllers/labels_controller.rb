class LabelsController < AdminController
  layout "admin"

  def index
    @families = Family.all
  end

  def generate
    @families = Family.all

    respond_to do |format|
      format.pdf do
        pdf = LabelsPdf.new(@families.where(id: [ 79, 78, 77 ]))
        send_data pdf.render,
                  filename: "etiquetas_confirmacao.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end
end
