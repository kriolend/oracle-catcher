terraform {
  backend "gcs" {
    # Имя корзины (бакета) в Google Cloud. 
    # ВАЖНО: Имя должно быть уникальным во всем Google Cloud!
    # Замени "devops-lab-tfstate-твоеимя" на что-то свое, уникальное.
    bucket = "devops-lab-tfstate-u8197250572-2026"
    
    # Папка внутри бакета, куда будет положен файл
    prefix  = "terraform/state"
  }
}
