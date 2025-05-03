class ConfirmedMembersPdf < Prawn::Document
  def initialize(families)
    super(page_size: "A4", margin: 30)
    @families = families
    generate_content
  end

  def generate_content
    font_families.update("Roboto" => {
      normal: Rails.root.join("app/assets/fonts/Roboto-Regular.ttf"),
      bold: Rails.root.join("app/assets/fonts/Roboto-Bold.ttf"),
      italic: Rails.root.join("app/assets/fonts/Roboto-Italic.ttf")
    })
    font("Roboto")

    # Título
    text "Membros Confirmados por Família", size: 16, style: :bold, align: :center
    move_down 20

    # Data do relatório
    text "Relatório gerado em: #{I18n.l(Time.current, format: :long)}", size: 9, align: :right
    move_down 30

    # Total de famílias e membros
    total_confirmados = @families.sum(&:confirmed_members_count)
    text "Total de Famílias com Confirmações: #{@families.count}", size: 11
    text "Total de Membros Confirmados: #{total_confirmados}", size: 11
    move_down 20

    # Lista de famílias e membros
    @families.each_with_index do |family, index|
      text "#{family.name} (#{family.confirmed_members_count} #{family.confirmed_members_count == 1 ? 'membro' : 'membros'})", size: 12, style: :bold
      move_down 5

      # Tabela de membros confirmados
      membros = family.members.where(confirmed: true).map do |member|
        [
          member.name,
          member.age.present? ? "#{member.age} anos" : "-"
        ]
      end

      if membros.any?
        table([["Nome", "Idade"]] + membros, width: bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "EEEEEE"
          cells.padding = [5, 10]
          cells.borders = [:bottom]
          row(0).borders = [:bottom]
          columns(0).width = bounds.width * 0.7
          columns(1).width = bounds.width * 0.3
        end
      end

      move_down 15
      if index < @families.count - 1
        stroke_horizontal_rule
        move_down 15
      end
    end

    # Rodapé com paginação
    number_pages "Página <page> de <total>", at: [bounds.right - 150, 0], width: 150, align: :right, size: 9
  end
end
