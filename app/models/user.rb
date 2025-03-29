class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Considerando que todo usuário logado é admin
  def admin?
    true # Retorna true para permitir acesso a todos os usuários logados
  end
end
