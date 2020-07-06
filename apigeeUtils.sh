#!/bin/bash
version=1.0.1

# Valores por defecto
default_prop_file=apigee.env
default_dir_proxy=apiproxy
default_api_cmd=apigeetool

prop_file=$default_prop_file

if [ -n "$2" ];
then
   echo "Archivo de propiedades ingresado manualmente: $2"
   prop_file=$2
fi


if [[ -e "$prop_file" && -f "$prop_file" ]];
then
   # TODO: Controlar que vengan properties obligatorios y otros asignar por defecto
   echo "Leyendo properties $prop_file..."   
   org=`cat $prop_file | grep ^org= | cut -d'=' -f2`
   nom_proxy=`cat $prop_file | grep ^nom_proxy= | cut -d'=' -f2`
   env=`cat $prop_file | grep ^env= | cut -d'=' -f2`
   #Opcionales
   user=`cat $prop_file | grep ^user= | cut -d'=' -f2`
   pass=`cat $prop_file | grep ^pass= | cut -d'=' -f2`
   dir_proxy=`cat $prop_file | grep ^dir_proxy= | cut -d'=' -f2`
   api_cmd=`cat $prop_file | grep ^api_cmd= | cut -d'=' -f2`

   if [ -z "$org" ]; then echo "Parámetro <org> es obligatorio. Finalizando script."; exit 101; fi 
   if [ -z "$nom_proxy" ]; then echo "Parámetro <nom_proxy> es obligatorio. Finalizando script."; exit 102; fi 
   if [ -z "$env" ]; then echo "Parámetro <env> es obligatorio. Finalizando script."; exit 103; fi 


   if [ -z "$dir_proxy" ]; then dir_proxy=$default_dir_proxy; fi
   if [ -z "$api_cmd" ]; then api_cmd=$default_api_cmd; fi

   
   echo "================================================"
   echo -e "Usuario:\t$user\nOrganization:\t$org"
   echo -e "Proxy:\t\t$nom_proxy\nEntornos:\t$env"
   echo -e "Directorio del proxy:\t$dir_proxy"
   #echo -e "Aplicativo Apigee tool:\t$api_cmd"
   echo "================================================"
   
   if [ -n "$user" ]; then user="--username $user"; fi
   if [ -n "$pass" ]; then pass="--password $pass"; fi

else
   echo "Archivo de propiedades <<$prop_file>> no encontrado."

   if [[ ! ( -e "$default_prop_file" && -f "$default_prop_file" ) ]];
   then
      echo "El archivo por defecto <<$default_prop_file>> tampoco existe. El script finalizará, pero antes intentará crearlo."
      
      echo -n "Ingrese el nombre de la organización de su cuenta Apigee (por ej. usuario-eval): "
      read new_org
      echo -n "Ingrese el nombre del proxy en el portal apigee para este proyecto (por ej. defaultProxy): "
      read new_nom_proxy
      echo -n "Ingrese el nombre del entorno en el cual trabajará en el portal Apigee. Si es más de uno, ingréselos sin espacios y separados por coma (por ej. dev,qa): "
      read new_env
         
      echo -e "\nCreando archivo $default_prop_file"
      touch $default_prop_file
      echo '# Nombres de propiedades no deben tener espacio al inicio o después (REGEXP ^nombre=valor)' > $default_prop_file
      echo '# Parámetros de la cuenta Apigee' >> $default_prop_file
      echo '#user=usuario@netred.cl' >> $default_prop_file
      echo '#pass=miclaveapigee' >> $default_prop_file
      echo "org=$new_org" >> $default_prop_file
      echo '# Parámetros del Proxy en portal Apigee' >> $default_prop_file
      echo "nom_proxy=$new_nom_proxy" >> $default_prop_file
      echo "env=$new_env" >> $default_prop_file
      echo '# Parámetros del proyecto' >> $default_prop_file
      echo '#dir_proxy=apiproxy' >> $default_prop_file
      echo '#Parámetros de entorno' >> $default_prop_file
      echo '#api_cmd=apigeetool' >> $default_prop_file
   
      echo "Archivo <<$default_prop_file>> creado. Script finalizado."
      exit 2      
   fi

   exit 1
fi

case $1 in
   upload)
      echo "Iniciando subida de proxy..."
      $api_cmd deployproxy $user $pass --organization $org --api $nom_proxy -d . -V --import-only
      ;;
   deploy)
      $api_cmd deployproxy $user $pass --organization $org --api $nom_proxy -d . -V --environments $env
      ;;
   download)
      echo 'Introduce la revision a descargar:'
      read num_rev
      $api_cmd fetchproxy $user $pass --organization $org --api $nom_proxy --revision $num_rev --file $nom_proxy\_rev$num_rev.zip
      ;;
   change_deploy)
      echo "Introduce la revision a deployar en <<$env>>:"
      read num_rev
      $api_cmd deployExistingRevision $user $pass --organization $org --environments $env --api $nom_proxy --revision $num_rev
      ;;
   list_deploy)
      echo "Iniciando listado de proxys..."
      $api_cmd listdeployments $user $pass --organization $org --api $nom_proxy --long
      ;;
   version)
      echo "$version"
      ;;
   help)
      echo -e "NOMBRE\n\t$0\n"
      echo -e "VERSIÓN\n\t$version\n"
      echo -e "USO\n\t$0 ACTION [PROPERTIES_FILE]\n"
      echo -e -n "DESCRIPCIÓN\n\t"
      echo -e "Wrapper para herramienta ApigeeTool (https://www.npmjs.com/package/apigeetool)\n"
      
      echo -e "ACTION" 
      
      echo -e -n '\n\t'
      echo -e -n 'upload\n\t\t'
      echo -e 'Sube una nueva revisión del proxy al portal Apigee, pero no lo despliega'

      echo -e -n '\n\t'
      echo -e -n 'deploy\n\t\t'
      echo -e 'Sube una nueva revisión del proxy al portal Apigee y lo despliega en los entornos definidos'

      echo -e -n '\n\t'
      echo -e -n 'download\n\t\t'
      echo -e 'Descarga una revisión determinada del proxy desde el portal Apigee'
      
      echo -e -n '\n\t'
      echo -e -n 'change_deploy\n\t\t'
      echo -e 'Despliegua en los entornos definidos, la revisión de la API ya existente en portal Apigee.'
      
      echo -e -n '\n\t'
      echo -e -n 'list_deploy\n\t\t'
      echo -e 'Lista los proxy desplegados en todos los entornos del portal Apigee.'
      
      echo -e -n '\n\t'
      echo -e -n 'help\n\t\t'
      echo -e 'Imprime esta ayuda'
      
      echo -e -n "\nPROPERTIES_FILE\n\t\t"
      echo -e -n "Nombre del archivo con las propiedades a leerse. Si no se especifica, se usa <<$default_prop_file>>.\n\t\t"
      echo -e "Si tanto PROPERTIES_FILE como <<$default_prop_file>> no existen, el script creará una plantilla de <<$default_prop_file>>."
      
      ;;
   *)
      #TODO: pasar opciones a arreglo y pintar arreglo to string y en case poner índices arreglo
      echo 'Opción inválida (upload | deploy | download | change_deploy | list_deploy | version | help)'
      echo -e "\n$0 ACTION [PROPERTIES_FILE]\n"
      ;;
esac


exit 0

# TODO: Corregir problema con espacios en comandos
#zip_cmd="'C:\Program Files\7-Zip\7z.exe'"
#unzip_cmd='"C:\Program Files\7-Zip\7z.exe"'
comprimir(){
   echo 'Introduce la revision:'
   read num_rev
   $zip_cmd a Revision_$num_rev.zip $dir_proxy
}

downloadRevision(){
   echo 'No implementada aún'
   #TODO:
   #Download
   #unzip
   #Pedir confirmación
   #borrar fuentes (opcional, revisar por control de versiones; otra alternativa hacer diff con winmerge u otro)
   #copiar dentro de apiproxy
}
downloadRevision

testfunction(){
   echo "My first function"
}
testfunction
