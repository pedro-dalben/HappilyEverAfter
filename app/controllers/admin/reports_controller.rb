module Admin
  class ReportsController < AdminController
    layout "admin"

    def index
      # Página principal que lista todos os relatórios disponíveis
    end

    def family_stats
      @families = Family.includes(:members).all

      respond_to do |format|
        format.html
        format.pdf do
          pdf = FamilyStatsPdf.new(@families)
          send_data pdf.render,
                    filename: "familias_confirmadas_estatisticas.pdf",
                    type: "application/pdf",
                    disposition: "inline"
        end
      end
    end

    def confirmed_members
      @families = Family.includes(:members).select { |f| f.confirmed_members_count > 0 }

      respond_to do |format|
        format.html
        format.pdf do
          pdf = ConfirmedMembersPdf.new(@families)
          send_data pdf.render,
                    filename: "membros_confirmados_por_familia.pdf",
                    type: "application/pdf",
                    disposition: "inline"
        end
      end
    end
  end
end
