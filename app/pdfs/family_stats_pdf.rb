require "prawn"
require "prawn/table"

class FamilyStatsPdf < Prawn::Document
  def initialize(families)
    super(
      page_size: "A4",
      margin: [30, 30, 30, 30],
      page_layout: :portrait
    )

    # Configurações de fonte
    font_families.update(
      "Helvetica" => {
        normal: "Helvetica",
        bold: "Helvetica-Bold",
        italic: "Helvetica-Oblique",
        bold_italic: "Helvetica-BoldOblique"
      }
    )
    font "Helvetica"

    # Gerar o relatório
    @families = families
    generate_header
    generate_stats_summary
    generate_family_details if @families.any?
  end

  private

  def generate_header
    text "Relatório de Famílias com Membros Confirmados", size: 18, style: :bold, align: :center
    text "Data de Geração: #{Time.current.strftime('%d/%m/%Y às %H:%M')}", size: 10, align: :center
    move_down 20
    stroke_horizontal_rule
    move_down 20
  end

  def generate_stats_summary
    # Cálculo das estatísticas
    total_families = @families.count
    total_families_with_confirmations = @families.select { |f| f.confirmed_members_count > 0 }.count
    total_confirmed_members = @families.sum(&:confirmed_members_count)

    # Contagem por faixa etária
    adults_count = count_by_age_range(12..Float::INFINITY)
    children_6_to_12_count = count_by_age_range(6...12)
    children_0_to_5_count = count_by_age_range(0...6)

    text "Resumo Geral", size: 14, style: :bold
    move_down 10

    # Construindo o array de dados apenas com valores não-zero
    summary_data = [
      ["Total de Famílias", "#{total_families}"],
      ["Famílias com Confirmações", "#{total_families_with_confirmations}"],
      ["Total de Membros Confirmados", "#{total_confirmed_members}"],
      ["", ""]
    ]

    # Adiciona apenas categorias com valores maiores que zero
    summary_data << ["Adultos (12+ anos)", "#{adults_count}"] if adults_count > 0
    summary_data << ["Crianças (6-12 anos)", "#{children_6_to_12_count}"] if children_6_to_12_count > 0
    summary_data << ["Crianças (0-5 anos)", "#{children_0_to_5_count}"] if children_0_to_5_count > 0

    table summary_data, width: 400 do
      cells.borders = []
      column(0).font_style = :bold
      column(0).width = 200
      column(1).align = :right
      row(3).padding = [10, 0]

      # Cores dinâmicas baseadas nas categorias presentes
      row_index = 4
      if adults_count > 0
        row(row_index).text_color = "003366"
        row_index += 1
      end

      if children_6_to_12_count > 0
        row(row_index).text_color = "006633"
        row_index += 1
      end

      if children_0_to_5_count > 0
        row(row_index).text_color = "993300"
      end
    end

    move_down 30
    stroke_horizontal_rule
    move_down 20
  end

  def generate_family_details
    text "Detalhes por Família", size: 14, style: :bold
    move_down 10

    # Criar a tabela de detalhes por família
    families_with_confirmations = @families.select { |f| f.confirmed_members_count > 0 }

    families_with_confirmations.each_with_index do |family, index|
      text "#{index + 1}. #{family.name}", size: 12, style: :bold
      move_down 5

      adults = family.members.where(confirmed: true).select { |m| m.age && m.age >= 12 }.count
      children_6_to_12 = family.members.where(confirmed: true).select { |m| m.age && m.age >= 6 && m.age < 12 }.count
      children_0_to_5 = family.members.where(confirmed: true).select { |m| m.age && m.age < 6 }.count

      # Construindo apenas com valores não-zero
      family_data = []
      family_data << ["Adultos (12+ anos)", "#{adults}"] if adults > 0
      family_data << ["Crianças (6-12 anos)", "#{children_6_to_12}"] if children_6_to_12 > 0
      family_data << ["Crianças (0-5 anos)", "#{children_0_to_5}"] if children_0_to_5 > 0
      family_data << ["Total", "#{family.confirmed_members_count}"]

      table family_data, width: 400 do
        cells.borders = []
        column(0).font_style = :bold
        column(0).width = 200
        column(1).align = :right

        # Cores dinâmicas baseadas nas categorias presentes
        row_index = 0
        if adults > 0
          row(row_index).text_color = "003366"
          row_index += 1
        end

        if children_6_to_12 > 0
          row(row_index).text_color = "006633"
          row_index += 1
        end

        if children_0_to_5 > 0
          row(row_index).text_color = "993300"
          row_index += 1
        end

        row(row_index).font_style = :bold
      end

      move_down 15
    end
  end

  def count_by_age_range(range)
    count = 0
    @families.each do |family|
      count += family.members.where(confirmed: true).select { |m| m.age && range.include?(m.age) }.count
    end
    count
  end
end
