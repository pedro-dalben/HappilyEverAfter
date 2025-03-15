require "prawn"
require "prawn/table"

class LabelsPdf < Prawn::Document
  # Método para converter cm para pontos (1cm = 28.35 pontos)
  def cm(cm_value)
    cm_value * 28.35
  end

  def initialize(families)
    # Configurar o documento com medidas em cm convertidas para pontos
    super(
      page_size: "A4",
      margin: [ cm(1.0), cm(1.0), cm(1.0), cm(1.0) ],
      page_layout: :portrait
    )

    # Definir número de colunas desejado (fixo em 3)
    @columns = 3

    # Calcular o espaçamento entre etiquetas
    @spacing = cm(0.3)

    # Calcular a largura da etiqueta para preencher toda a página
    # (largura total - espaçamentos) / número de colunas
    @label_width = (bounds.width - (@spacing * (@columns - 1))) / @columns

    # Defina a altura da etiqueta (por exemplo, 4cm)
    @label_height = cm(4)  # Ajuste a altura aqui
    @label_border = cm(0.1)

    # Definir fonte padrão
    font_families.update(
      "Helvetica" => {
        normal: "Helvetica",
        bold: "Helvetica-Bold",
        italic: "Helvetica-Oblique",
        bold_italic: "Helvetica-BoldOblique"
      }
    )
    font "Helvetica"

    # Gerar etiquetas para cada família
    generate_labels(families)
  end

  def generate_labels(families)
    # Contador para posicionamento das etiquetas
    x_position = 0
    y_position = cursor

    families.each_with_index do |family, index|
      # Verificar se precisamos mudar de linha
      if x_position >= @columns
        x_position = 0
        y_position -= (@label_height + @spacing)

        # Verificar se precisamos de uma nova página
        if y_position < @label_height
          start_new_page
          y_position = cursor
        end
      end

      # Posição da etiqueta atual
      x = x_position * (@label_width + @spacing)
      y = y_position

      # Verifica se é uma família ou pessoa individual
      is_family = family.name.match?(/\s+e\s+|\s+E\s+|Família|Familia|Family/)
      confirmation_text = is_family ?
                         "Para confirmarem a presença, acesse o site:" :
                         "Para confirmar a presença, acesse o site:"

      # Desenhar etiqueta
      bounding_box([ x, y ], width: @label_width, height: @label_height) do
        # Desenhar borda
        stroke do
          stroke_color "000000"
          line_width @label_border
          rectangle [ 0, @label_height ], @label_width, @label_height
        end

        # Conteúdo da etiqueta
        stroke_color "FFFFFF"
        fill_color "000000"

        # Nome da família com quebra de linha
        text_box family.name,
                 at: [ @label_border * 2, @label_height - @label_border * 4 ],
                 width: @label_width - @label_border * 4,
                 height: @label_height * 0.25,
                 align: :center,
                 valign: :top,
                 style: :bold,
                 size: 13,
                 overflow: :shrink_to_fit,  # Permite que o texto se ajuste
                 min_font_size: 8  # Tamanho mínimo da fonte para evitar que fique muito pequeno

        # Texto de confirmação - agora dinâmico
        text_box confirmation_text,
                 at: [ @label_border * 2, @label_height * 0.65 ],
                 width: @label_width - @label_border * 4,
                 height: @label_height * 0.2,
                 align: :center,
                 size: 10

        # Site
        text_box "giovanaepedro.com.br",
                 at: [ @label_border * 2, @label_height * 0.45 ],
                 width: @label_width - @label_border * 4,
                 height: @label_height * 0.2,
                 align: :center,
                 size: 11,
                 style: :bold

        # Texto código
        text_box "e utilize o código:",
                 at: [ @label_border * 2, @label_height * 0.33 ],
                 width: @label_width - @label_border * 4,
                 height: @label_height * 0.2,
                 align: :center,
                 size: 10

        # Código
        text_box family.token,
                 at: [ @label_border * 2, @label_height * 0.20 ],
                 width: @label_width - @label_border * 4,
                 height: @label_height * 0.2,
                 align: :center,
                 size: 14,
                 style: :bold
      end

      # Atualizar posição para a próxima etiqueta
      x_position += 1
    end
  end
end
