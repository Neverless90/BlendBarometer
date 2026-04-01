<h5>Module gegevens sectie</h5>
<p>Bewerk de beschrijvingstekst die wordt getoond boven de Module gegevens sectie op de gegevenspagina.</p>
<form action="{{ route('admin.edit-content.information-module-update') }}" method="POST"
      class="form w-100 d-flex justify-content-end">
    @csrf
    @method('PUT')
    <div class="editor mb-2 bg-white">
        {!! $moduleDescription !!}
    </div>
</form>
@error('content') <p class="text-danger fw-bold small">{{ $message }}</p> @enderror
