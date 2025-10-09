import React from 'react'
import Accordion from 'react-bootstrap/Accordion';
import ListGroup from 'react-bootstrap/ListGroup';

function PanelIntro() {
  return (
    <div className="container mt-4">
      <div className="p-4 bg-light rounded shadow-sm">
        
        

      </div>

        <Accordion defaultActiveKey="0" flush>
            <Accordion.Item eventKey="0">
                <Accordion.Header><h2 className="mb-3 text-dark">¿Qué es el Panel de Reportes?</h2></Accordion.Header>
                <Accordion.Body>
                    <p className="text-secondary fs-5">
                        Este panel te permite visualizar, organizar y exportar información proveniente de la base de datos de forma clara y estructurada. 
                        A través de los botones del menú superior, puedes acceder a diferentes tipos de consultas como reportes generales.
                    </p>
                    <p className="text-secondary fs-5">
                        Cada sección está diseñada para mostrar los datos en tablas, listas para imprimir según tus necesidades. 
                        El objetivo es facilitar el análisis de <strong>CMC AUDITORES Y CONSULTORES</strong>  mediante una interfaz intuitiva y eficiente. <br />
                    </p>
                </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="1">
                <Accordion.Header><h2 className='mb-3 text-dark'>¿Cómo imprimo los reportes?</h2></Accordion.Header>
                <Accordion.Body>
                    <ListGroup>
                        <ListGroup.Item>1. En la parte superior verás varios botones</ListGroup.Item>
                        <ListGroup.Item>2. Selecciona la Query deseada</ListGroup.Item>
                        <ListGroup.Item>3. Cuando cargue el nuevo apartado, presionar le botón "Imprimir Reporte"</ListGroup.Item>
                        <ListGroup.Item>4. ¡Ya puedes visualizar su Reporte!</ListGroup.Item>
                    </ListGroup>
                </Accordion.Body>
            </Accordion.Item>
        </Accordion>

    </div>
  );
}

export default PanelIntro;