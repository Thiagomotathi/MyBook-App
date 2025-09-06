# 📚 MyBookApp

MyBookApp é um aplicativo em SwiftUI que permite explorar livros através da API do **Google Books**, organizar leituras pessoais e acompanhar hábitos de leitura.  
O projeto foi desenvolvido com arquitetura **MVVM** e foco em simplicidade, organização e extensibilidade.

---

## 🚀 Funcionalidades

- 🔍 **Buscar livros** pela API do Google Books.  
- 📖 **Detalhes completos do livro** (autor, descrição, número de páginas e capa em alta qualidade).  
- 📝 **Lista de leitura personalizada**, onde o usuário pode salvar livros para acompanhar.  
- ⏱️ **Sessão de leitura temporizada**, com popup ao encerrar a sessão perguntando quantas páginas foram lidas.  
- 📊 **Acompanhamento de progresso de leitura** (quantidade de páginas lidas vs. total).  
- 🎨 **Fundo animado com círculos suaves**, deixando a interface mais agradável.  
- 🗂️ Organização do código em **MVVM** para fácil manutenção e escalabilidade.

---

## 🏗️ Arquitetura

O app segue o padrão **MVVM (Model-View-ViewModel)**:

- **Model** → Representa os dados vindos da API do Google Books.  
- **ViewModel** → Contém a lógica de negócio (ex.: busca de livros, progresso de leitura).  
- **View** → Interface em SwiftUI, reativa ao estado exposto pelos ViewModels.  

---

## 📱 Estrutura das Abas (TabView)

- **Leituras** → Lista de livros salvos e progresso.  
- **Explorar** → Espaço para futuras expansões (descobrir novos livros).  
- **Perfil** → Informações do usuário.  
- **Buscar** → Aba especial com **Search Role**, integrando a busca diretamente na Tab Bar.  

---

## 🛠️ Tecnologias Utilizadas

- **SwiftUI** (UI declarativa)  
- **Combine** (reatividade de estados)  
- **MVVM** (organização de código)  
- **Google Books API** (busca e dados de livros)  

---

## 🎯 Futuras Melhorias

- Integração com **estatísticas mais detalhadas** de leitura.  
- Suporte a **notificações** para lembrar sessões de leitura.  
- **Sincronização em nuvem** para backup da lista de leituras.  

---

## 📸 Screenshots (em breve)

*(Aqui você pode adicionar prints da interface do app para deixar o repositório mais visual.)*

---

## 👨‍💻 Autor

Desenvolvido por **Thiago Mota Machado** ✨  
