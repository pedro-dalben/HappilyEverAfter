import { Controller } from "@hotwired/stimulus";
import Swal from "sweetalert2";

export default class extends Controller {
  static values = { url: String }

  connect() {
    console.log("DeleteController conectado!", this.urlValue);
  }

  confirm(event) {
    console.log(this.urlValue)
    event.preventDefault();
    event.stopPropagation();

    Swal.fire({
      title: "Tem certeza?",
      text: "Essa ação não pode ser desfeita!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Sim, deletar!"
    }).then((result) => {
      if (result.isConfirmed) {
        this.deleteItem();
      }
    });
  }

  async deleteItem() {
    try {
      const response = await fetch(this.urlValue, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
          "Content-Type": "application/json"
        }
      });

      if (response.ok) {
        Swal.fire({
          title: "Deletado!",
          text: "A família foi removida com sucesso.",
          icon: "success",
          timer: 1500,
          showConfirmButton: false
        }).then(() => {
          this.element.closest("tr").remove();
        });
      } else {
        throw new Error("Erro ao deletar.");
      }
    } catch (error) {
      console.error("Erro na requisição:", error);
      Swal.fire("Erro!", "Algo deu errado ao deletar.", "error");
    }
  }
}
